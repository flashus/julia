## types ##

(<:)(T, S) = subtype(T,S)
(>:)(T, S) = subtype(S,T)

## definitions providing basic traits of arithmetic operators ##

# fallback definitions for emulating N-arg operators with 2-arg definitions
(*)() = 1
(*)(x::Tensor) = x
(*)(a,b,c) = (*)((*)(a,b),c)
(*)(a,b,c,d) = (*)((*)((*)(a,b),c),d)
(*)(a,b,c,d,e) = (*)((*)((*)((*)(a,b),c),d),e)
function (*)(x1, x2, x3, xs...)
    accum = (*)((*)(x1,x2),x3)
    for x = xs
        accum = accum * x
    end
    accum
end

(+)() = 0
(+)(x::Tensor) = x
(+)(a,b,c) = (+)((+)(a,b),c)
(+)(a,b,c,d) = (+)((+)((+)(a,b),c),d)
(+)(a,b,c,d,e) = (+)((+)((+)((+)(a,b),c),d),e)
function (+)(x1, x2, x3, xs...)
    accum = (+)((+)(x1,x2),x3)
    for x = xs
        accum = accum + x
    end
    accum
end

# .<op> defaults to <op>
(./)(x,y) = x/y
(.\)(x,y) = y./x
(.*)(x,y) = x*y

div(x::Number, y::Number) = truncate(x/y)
(%)(x::Number, y::Number) = x-div(x,y)*y
mod(x,y) = x%y
mod1(x,y) = mod(x-one(x),y)+one(x) # TODO: broken <= 0
(\)(x,y) = y/x

oftype{T}(x::T,c) = convert(T,c)
oftype{T}(x::Type{T},c) = convert(T,c)

sizeof{T}(x::T) = sizeof(T)
sizeof(t::Type) = error(strcat("size of type ",string(t)," unknown"))

zero(x) = oftype(x,0)
one(x)  = oftype(x,1)

## comparison ##

!=(x, y) = !(x == y)
> (x, y) = (y < x)
<=(x, y) = (x < y) || (x == y)
>=(x, y) = (x > y) || (x == y)
<=(x::Real, y::Real) = (x < y) || (x == y)
>=(x::Real, y::Real) = (x > y) || (x == y)

## promotion mechanism ##

promote_type{T}(::Type{T}, ::Type{T}) = T

function promote_type{T,S}(::Type{T}, ::Type{S})
    # print("promote_type: ",T,", ",S,"\n")
    if method_exists(promote_rule,(T,S))
        return promote_rule(T,S)
    elseif method_exists(promote_rule,(S,T))
        return promote_rule(S,T)
    else
        error(strcat("no promotion exists for ",string(T)," and ",string(S)))
    end
end

promote() = ()
promote(x) = (x,)
function promote{T,S}(x::T, y::S)
    # print("promote: ",T,", ",S,"\n")
    #R = promote_type(T,S)
    # print("= ", R,"\n")
    (convert(promote_type(T,S),x), convert(promote_type(T,S),y))
end
function promote{T,S,U}(x::T, y::S, z::U)
    R = promote_type(promote_type(T,S), U)
    convert((R...), (x, y, z))
end
function promote{T,S}(x::T, y::S, zs...)
    R = promote_type(T,S)
    for z = zs
        R = promote_type(R,typeof(z))
    end
    convert((R...), tuple(x,y,zs...))
end

## promotion in arithmetic ##

(+)(x::Number, y::Number) = (+)(promote(x,y)...)
(*)(x::Number, y::Number) = (*)(promote(x,y)...)
(-)(x::Number, y::Number) = (-)(promote(x,y)...)
(/)(x::Number, y::Number) = (/)(promote(x,y)...)

## promotion in comparisons ##

(<) (x::Real, y::Real)     = (<)(promote(x,y)...)
(==)(x::Number, y::Number) = (==)(promote(x,y)...)

# these are defined for the fundamental < and == so that if a method is
# not found for e.g. <=, it is translated to < and == first, then promotion
# is handled after.

## integer-specific promotions ##

(%)(x::Int, y::Int) = (%)(promote(x,y)...)
div(x::Int, y::Int) = div(promote(x,y)...)

(&)(x::Int...) = (&)(promote(x...)...)
(|)(x::Int...) = (|)(promote(x...)...)
($)(x::Int...) = ($)(promote(x...)...)

## promotion catch-alls for undefined operations ##

no_op_err(name, T) = error(strcat(name," not defined for ",string(T)))
(+){T<:Number}(x::T, y::T) = no_op_err("+", T)
(*){T<:Number}(x::T, y::T) = no_op_err("*", T)
(-){T<:Number}(x::T, y::T) = no_op_err("-", T)
(/){T<:Number}(x::T, y::T) = no_op_err("/", T)
(<){T<:Real}  (x::T, y::T) = no_op_err("<", T)
(==){T<:Number}(x::T, y::T) = no_op_err("==", T)

(%){T<:Int}(x::T, y::T) = no_op_err("%", T)
div{T<:Int}(x::T, y::T) = no_op_err("div", T)
(&){T<:Int}(x::T, y::T) = no_op_err("&", T)
(|){T<:Int}(x::T, y::T) = no_op_err("|", T)
($){T<:Int}(x::T, y::T) = no_op_err("$", T)

## pointer comparison ##

==(x::Ptr, y::Ptr) = eq_int(unbox(Ptr,x),unbox(Ptr,y))

## miscellaneous ##

copy(x::Any) = x

function assert(c)
    if !c
        error("Assertion failed.")
    end
    true
end