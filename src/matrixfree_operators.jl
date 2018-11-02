import LinearAlgebra: mul!
mutable struct MatrixFreeOperator{F,N} <: AbstractMatrixFreeOperator{F}
  f::F
  args::N
  function MatrixFreeOperator(f::F, args::N) where {F,N}
    @assert (N <: Tuple && length(args) in (1,2)) "Arguments of a "*
    "MatrixFreeOperator must be a tuple with one or two elements"
    return new{F,N}(f, args)
  end
end
MatrixFreeOperator(f) = MatrixFreeOperator(f, (nothing,))

# Interface
is_constant(M::MatrixFreeOperator) = length(M.args) == 1
function update_coefficients!(M::MatrixFreeOperator, u, p, t)
  !is_constant(M) && (M.args = (p, t))
  return M
end

function (M::MatrixFreeOperator{F,N})(du, u, p, t) where {F,N}
  update_coefficients!(M,u,p,t)
  if is_constant(M)
    M.f(du, u, p)
  else
    M.f(du, u, p, t)
  end
  du
end

function (M::MatrixFreeOperator{F,N})(u, p, t) where {F,N}
  update_coefficients!(M,u,p,t)
  du = similar(u)
  if is_constant(M)
    M.f(du, u, p)
  else
    M.f(du, u, p, t)
  end
  du
end

@inline function mul!(y::AbstractVector, A::MatrixFreeOperator{F,N}, x::AbstractVector) where {F,N}
  if is_constant(A)
    A.f(y, x, A.args[1])
  else
    A.f(y, x, A.args[1], A.args[2])
  end
  return y
end

@inline function mul!(Y::AbstractMatrix, A::MatrixFreeOperator{F,N}, X::AbstractMatrix) where {F,N}
  m,  n = size(Y)
  k, _n = size(X)
  if n != _n
    throw(DimensionMismatch("the second dimension of Y, $N, does not match the second dimension of X, $_n"))
  end
  for i in 1:n
    y = view(Y, :, i)
    x = view(X, :, i)
    mul!(y, A, x)
  end
  Y
end
@inline Base.:*(A::MatrixFreeOperator, X::AbstractVecOrMat) = mul!(similar(X), A, X)

DiffEqBase.numargs(::MatrixFreeOperator) = 4
