@extends('layouts.app')

@section('content')

@include('partials._search-products')

@foreach ($products as $product)


<x-product-card :product="$product" />

@endforeach

<div class="pagination">
    {{ $products->links() }}

@endsection