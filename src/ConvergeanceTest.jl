"""
Circular buffer that does a test on all incoming values
    Returns true if all values pass the test, false otherwise
"""
mutable struct CircularAll{T, F} <: AbstractVector{T}
    const states::CircularBuffer{T}
    const tests::CircularBuffer{Bool}
    const test::F # Test function
    sum::Int
end

CircularAll(T::DataType, len::Integer, test::F) where F = CircularAll{T, F}(CircularBuffer{T}(len), CircularBuffer{Bool}(len), test, 0)

function push!(ca::CircularAll{T}, val::OT) where {T, OT >: T} 
    this_test = ca.test(val)::Bool
    states = ca.states
    if isfull(states) # Pop the first value subtract the test to the sum
        oldtest = popfirst!(ca.tests)
        push!(ca.tests, this_test)
        push!(ca.states, val)
        ca.sum += this_test - oldtest
    else
        push!(ca.tests, this_test)
        push!(ca.states, val)
        ca.sum += this_test
    end
    return ca
end

Base.all(ca::CircularAll) = ca.sum == length(ca.tests)

function delta_last_two(init)
    storage = CircularBuffer{typeof(init)}(2)
    push!(storage, init)
    anonymous = nothing
    let storage = storage
        anonymous =  x -> begin
            push!(storage, x)
            return storage[2] - storage[1]
        end
    end
    return anonymous
end

struct ConvergeanceTest{T, F} <: ProcessAlgorithm
    eltype::Type{T}
    tol::T
    windowsize::Int
    close_upon_convergence::Bool
    test::F
end

ConvergeanceTest(test, tol::T, windowsize::Int; close_upon_convergence::Bool = true) where T = ConvergeanceTest(T, tol, windowsize, close_upon_convergence, test)

function init!(alg::ConvergeanceTest{T}, context) where T
    testwindow = CircularAll{T}(alg.windowsize, x -> abs(x) < alg.tol)
    return (testwindow = testwindow, converged = false)
end

function step!(alg::ConvergeanceTest{T}, context) where T
    (;sample, testwindow) = context
    push!(testwindow, sample)
    converged = all(testwindow)
    if converged && alg.close_upon_convergence
        closeprocess(context)
    end
    return (testwindow = testwindow, converged = converged)
end





