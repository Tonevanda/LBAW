@extends('layouts.app')

<?php
    $total = 0;
    $productCount = count($products);
?>
@section('content')
    <h1>Wishlist</h1>
    @foreach ($products as $product)
    <x-wishlist-product-card :product="$product"/>
    @endforeach

@endsection
