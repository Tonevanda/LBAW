@extends('layouts.app')

<?php
    $total = 0;
    $productCount = count($products);
?>
@section('content')
    <h1>Shopping Cart</h1>
    @foreach ($products as $product)
    @php
        $total = $total + $product->price;
    @endphp
    <x-cart-product-card :product="$product" />

    @endforeach
    <table>
        <tr>
            <td colspan="1">Price</td>
            <td colspan="1">Quantity</td>
        </tr>
        <tr>
            <td>{{ $total }}</td>
            <td>{{ $productCount }}</td>
        </tr>
    </table>
    <a class="button" href="{{ url('/checkout') }}">Checkout</a>   

@endsection
