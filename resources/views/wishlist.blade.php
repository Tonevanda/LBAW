@extends('layouts.app')

<?php
    $total = 0;
    $productCount = count($products);
?>
@section('content')
<div class="wishlist-page">
    <h2>Wishlist</h2>
    @foreach ($products as $product)
    <x-wishlist-product-card  :user="$user" :product="$product"/>
    @endforeach
</div>
@endsection