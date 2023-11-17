@extends('layouts.app')

@section('content')

@foreach ($products as $product)

<x-product-card :product="$product" />

@endforeach

<div class="pagination">
    {{ $products->links() }}

@endsection