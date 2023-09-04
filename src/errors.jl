symbol_error() = throw(error("A symbol is expected for the second argument"))

_bound_error() = throw(error("Initial/Final bound not in the total bound"))

input_style_error() = throw(error("Keyword argument input style incorrect, make sure all arguments are in the form of keyword = value"))

diff_var_input_style_error() = throw(error("Incorrect use of 'keyword = value' and 'keyword in value'"))

multiple_independent_var_error() = throw(error("Only one independent variable is allowed, please use set_independent_var to change the independent variable"))

function same_var_error(_model,sym) 
    t = collect(keys(_model.Independent_var_index))
    i = collect(keys(_model.Initial_Independent_var_index))
    f = collect(keys(_model.Final_Independent_var_index))
    diff = collect_keys(_model.Differential_var_index)
    alg = collect_keys(_model.Algebraic_var_index)
    con = collect(keys(_model.Constant_index))

    append!(diff,alg)
    append!(diff,t)
    append!(diff,i)
    append!(diff,f)
    append!(diff,con)

    if sym in diff
        throw(error("The symbol $(sym) is already used in the model"))
    end
end

function check_vector_input(_expr)
    length(_expr.args) == 2 ? nothing : throw(error("Incorrect input style of vector."))
    
    #independent_var = collect(keys(_model.Independent_var_index))[1]          && (_expr.args[1].args[2] == independent_var) 
    
    (_expr.args[1] isa Expr) && (length(_expr.args[1].args) == 2) ? nothing : throw(error("Incorrect input style of vector."))

    (_expr.args[2].head == :call) && (length(_expr.args[2].args) == 3) && (_expr.args[2].args[1] == :(:)) ? nothing : throw(error("Incorrect input style of vector."))

    (_expr.args[2].args[2] == 1) && (_expr.args[2].args[3] isa Int64) && (_expr.args[2].args[3] > 1) ? nothing : throw(error("Incorrect input style of vector."))

    return _expr.args[2].args[3]
end

function check_contradict(collection,val)
    val[1] <= val[2] ? nothing : throw(error("Initial value greater than final value in the bound"))

    for i in eachindex(collection)
        if collection[i][1] >= val[2] || collection[i][2] <= val[1]
            throw(error("The bound $(val) contradicts with $(collection[i])"))
        end
    end
    
end

function check_alge_bound(val,bound)
    (bound[1] <= bound[2]) ? nothing : throw(error("Initial value greater than final value in the bound"))
    if val !== nothing
        (val >= bound[1] && val <= bound[2]) ? nothing : throw(error("The initial guess $(val) is not inside the bound $(bound)"))
    end
end

function check_modified(var)

   bound_lower_upper(var.Initial_bound) 
end

function bound_lower_upper(_bound)
    _bound[1] isa Real && _bound[2] isa Real ? nothing : throw(error("Elements in the bound must be real numbers"))
    _bound[1] < _bound[2] ? nothing : throw(error("Initial value greater than final value in the bound"))
end

function bound_not_inside_error(_initial_bound,_final_bound,_total_bound)
    _initial_bound[1] >= _total_bound[1] && _initial_bound[2] <= _total_bound[2] ? nothing : throw(error("Initial bound is not inside the trajectory bound"))
    _final_bound[1] >= _total_bound[1] && _final_bound[2] <= _total_bound[2] ? nothing : throw(error("Final bound is not inside the trajectory bound"))
end

function input_argument_error(_args)
    if length(_args) == 0
        symbol_error()
    elseif length(_args) > 1
        println("dd")
        multiple_independent_var_error()
    end
end

function check_initial_guess(_info)
    # check for the potential errors in the input bounds

    if _info[1] !== nothing
        _info[1] >= _info[2][1] && _info[1] <= _info[2][2] ? nothing : throw(error("The initial guess is not inside the initial bound"))
    end
end    

### Error messages for the algebraic variables
algebraic_input_style_error() = throw(error("Argument input style incorrect, make sure 'symbol in bound' is used expressions"))

######################

_Linear_algebra = [:/, :Adjoint, :BLAS, :Bidiagonal, :BunchKaufman, :Cholesky, :CholeskyPivoted, :ColumnNorm, :Diagonal, :Eigen, 
:Factorization, :GeneralizedEigen, :GeneralizedSVD, :GeneralizedSchur, :Hermitian, :Hessenberg, :I, :LAPACK, :LAPACKException, :LDLt, :LQ,
:LU, :LinearAlgebra, :LowerTriangular, :NoPivot, :PosDefException, :QR, :QRPivoted, :RankDeficientException, :RowMaximum, :SVD, :Schur, 
:SingularException, :SymTridiagonal, :Symmetric, :Transpose, :Tridiagonal, :UniformScaling, :UnitLowerTriangular, :UnitUpperTriangular, 
:UpperHessenberg, :UpperTriangular, :ZeroPivotException, :\, :adjoint, :adjoint!, :axpby!, :axpy!, :bunchkaufman, :bunchkaufman!, 
:cholesky, :cholesky!, :cond, :condskeel, :copy_transpose!, :copyto!, :cross, :det, :diag, :diagind, :diagm, :dot, :eigen, :eigen!, 
:eigmax, :eigmin, :eigvals, :eigvals!, :eigvecs, :factorize, :givens, :hessenberg, :hessenberg!, :isdiag, :ishermitian, :isposdef, 
:isposdef!, :issuccess, :issymmetric, :istril, :istriu, :kron, :ldiv!, :ldlt, :ldlt!, :lmul!, :logabsdet, :logdet, :lowrankdowndate, 
:lowrankdowndate!, :lowrankupdate, :lowrankupdate!, :lq, :lq!, :lu, :lu!, :lyap, :mul!, :norm, :normalize, :normalize!, 
:nullspace, :opnorm, :ordschur, :ordschur!, :pinv, :qr, :qr!, :rank, :rdiv!, :reflect!, :rmul!, :rotate!, :schur, :schur!, :svd, :svd!, 
:svdvals, :svdvals!, :sylvester, :tr, :transpose, :transpose!, :tril, :tril!, :triu, :triu!, :×, :⋅]

_Statistics = [:Statistics, :cor, :cov, :mean, :mean!, :median, :median!, :middle, :quantile, :quantile!, :std, :stdm, :var, :varm]

_Sparse_Arrays = [:AbstractSparseArray, :AbstractSparseMatrix, :AbstractSparseVector, :SparseArrays, :SparseMatrixCSC, :SparseVector, 
:blockdiag, :droptol!, :dropzeros, :dropzeros!, :findnz, :issparse, :nnz, :nonzeros, :nzrange, :permute, :rowvals, :sparse, :sparse_hcat, 
:sparse_hvcat, :sparse_vcat, :sparsevec, :spdiagm, :sprand, :sprandn, :spzeros]

_Special_Functions = [:SpecialFunctions, :airy, :airyai, :airyaiprime, :airyaiprimex, :airyaix, :airybi, :airybiprime, :airybiprimex, 
:airybix, :airyprime, :airyx, :besselh, :besselhx, :besseli, :besselix, :besselj, :besselj0, :besselj1, :besseljx, :besselk, :besselkx, 
:bessely, :bessely0, :bessely1, :besselyx, :beta, :beta_inc, :beta_inc_inv, :cosint, :dawson, :digamma, :ellipe, :ellipk, :erf, :erfc, 
:erfcinv, :erfcx, :erfi, :erfinv, :eta, :expint, :expinti, :expintx, :faddeeva, :gamma, :gamma_inc, :gamma_inc_inv, :hankelh1, :hankelh1x,
:hankelh2, :hankelh2x, :invdigamma, :jinc, :lbeta, :lbinomial, :lfact, :lfactorial, :lgamma, :lgamma_r, :logabsbeta, :logabsbinomial, 
:logabsgamma, :logbeta, :logerf, :logerfc, :logerfcx, :logfactorial, :loggamma, :ncF, :ncbeta, :polygamma, :sinint, :sphericalbesselj, 
:sphericalbessely, :trigamma, :zeta]

function mathematical_packages_functions(sym)
    (sym in _Linear_algebra) || (sym in _Statistics) || (sym in _Sparse_Arrays) || (sym in _Special_Functions) ? (return true) : (return false)
end