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
    @if ($errors->any())
    <div class="alert alert-danger">
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif
<form id="purchaseForm" method="POST" action="{{ route('purchase.store', ['user_id' => Auth::user()->id]) }}">
    {{ csrf_field() }}
    <input type="hidden" name="quantity" value="{{ $productCount }}">
    <input type="hidden" name="price" value="{{ $total }}">
    <button type="button" onclick="showMultiStepModal(event)" class="button button-outline">
Checkout
</button>

</form>

<!-- Multi-Step Modal HTML -->
<div id="multiStepModal" style="display: none;">
    <!-- Step 1 -->
    <div id="step1" class="step">
        <p>Step 1: Shipping Address</p>
        <label for="destination">Shipping Address:</label>
        <input type="text" id="destination" name="destination">
        <button onclick="showStep(2)">Next</button>
    </div>

    <!-- Step 2 -->
    <div id="step2" class="step" style="display: none;">
        <p>Step 2: Payment Method</p>
        <label for="payment_type">Payment Method:</label>
        <select id="payment_type" name="payment_type">
            <option value="paypal">PayPal</option>
            <option value="credit/debit card">Credit/Debit Card</option>
            <option value="store money">Wallet</option>
        </select>
        <button onclick="showStep(3)">Next</button>
        <button onclick="showStep(1)">Previous</button>
    </div>

    <!-- Step 3 -->
    <div id="step3" class="step" style="display: none;">
        <p>Step 3: Review and Confirm</p>
        <!-- Display a summary of the user's selections -->
        <button onclick="submitForm()">Confirm Purchase</button>
        <button onclick="showStep(2)">Previous</button>
    </div>

    <button onclick="hideMultiStepModal()">Cancel</button>
</div>

    
@endsection
        
