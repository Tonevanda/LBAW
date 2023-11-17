@extends('layouts.app')

@section('content')

@include('partials._search')

@foreach ($products as $product)
<div class="product">
    <a href="{{ route('single-product', $product) }}">
        <h2> {{ $product->name }} </h2>
        <p> {{ $product->synopsis }} </p>
        <p> {{ $product->price }} </p>
    </a>
</div>

@endforeach

<div class="pagination">
    {{ $products->links() }}

@endsection