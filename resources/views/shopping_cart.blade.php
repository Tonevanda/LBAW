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
    <form method="POST" action="{{ route('purchase.store', ['user_id' => Auth::user()->id]) }}">
        {{ csrf_field() }}
        <input type="hidden" name="quantity" value="{{ $productCount }}">
        <input type="hidden" name="price" value="{{ $total }}">
        <button type="submit" class="button button-outline">
            Checkout
        </button>
    </form>

@endsection
