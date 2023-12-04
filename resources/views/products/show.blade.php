@extends('layouts.app') 

@section('content')

    <h2> {{ $product->name }} </h2>
    <p> {{ $product->synopsis }} </p>
    <p> {{ $product->price }} </p>
    {{--<form action="{{ url('/shopping_cart') }}" method="POST">
        {{ csrf_field() }}
        <input type="hidden" name="product_id" value="{{ $product->id }}">
        <input type="submit" value="Add to Cart" class="button">
    </form>--}}
@endsection