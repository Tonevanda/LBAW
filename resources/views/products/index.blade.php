@extends('layouts.app')

@section('content')
<div class="home-container">
@include('partials._search-products')

<div class = "home-grid">
@foreach ($products as $product)

<x-product-card :product="$product" />

@endforeach
</div>
</div>
<div>
<ul class="pagination">
    {{ $products->links() }}
</ul>
</div>
@endsection