@extends('layouts.app')

<?php
    $total = 0;
    $productCount = count($products);
?>
@section('content')
    <h1>Shopping Cart</h1>
    <table>
        <thead>
            <tr>
                <th>Book</th>
                <th>Quantity</th>
                <th>Subtotal</th>
            </tr>
        </thead>
        <tbody>
            <?php 
                if($productCount == 0) {
                    echo "<tr><td colspan='3'>No items in cart</td></tr>";
                }
            ?>
            @foreach ($products as $product)
                <?php
                    $total += $product->price;
                ?>
                <x-product-card :product="$product" />
            @endforeach
        </tbody>
        <tfoot>
            <tr>
                <td colspan="1">Total</td>
                <td>{{ $productCount }}</td>
                <td>{{ $total }}</td>
            </tr>
        </tfoot>
    </table>
    <a class="button" href="{{ url('/checkout') }}">Checkout</a>   

@endsection
