@extends('layouts.app')


@php
    use App\Models\Payment;


    $user = Auth::user();
    if(!$user->isAdmin()){
        $auth = $user->authenticated()->first();
        $wallet = $auth->wallet()->first();
        $currency = $wallet->currency()->first();
        $payments = Payment::all();
    }
    $total = 0;
    $productCount = count($products);
@endphp

@section('content')
<div class="shopping-cart-page">
    <h2>Shopping Cart</h2>
    <div class="shopping-page">
    <section class = "product_listing">
        @foreach ($products as $product)
        @php
            $total = $total+($product->price-($product->discount*$product->price/100));
        @endphp
            <x-cart-product-card :product="$product" :user="$user"/>
        @endforeach
    </section>
    <table>
        <tr>
            <td>Quantity</td>
            <td>{{ $productCount }}</td>
        </tr>
        <tr>
            <td>Price</td>
            <td>{{ number_format($total/100, 2, ',', '.');}}{{$user->isAdmin() ? '€' : $currency->currency_symbol}}</td>
        </tr>
    </table>
    <button name="show_popup_checkout" data-money = {{ number_format($total/100, 2, ',', '.');}}{{$user->isAdmin() ? '€' : $currency->currency_symbol}}>
        Checkout
    </button>
</div>
</div>
    
@if ($errors->any())
    <div class="alert alert-danger">
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif
@if (!$user->isAdmin())
    <x-payment-popup-card :user="$user" :auth="$auth" :payments="$payments"/>
@endif



<div id="fullScreenPopup2" class="popup-form" style="display: none;">
    <form class = "checkout_form" method="" action="">
        {{ csrf_field() }}
        <div class="shipping-address">
            <div class="column">
                <p>Total cost of shopping cart</p>

            </div>
            <div class="column">
                <p></p>
            </div>
        </div>

        <p class = "payment_info">Bibliophile Bliss Account: {{$user->name}}</p>
        <p class = "payment_info"></p>

        <div class="shipping-address">
            <div class="column">
                <p class = "payment_info"></p>
                <p class = "payment_info"></p>

            </div>
            <div class="column">
                <button name="back"> Change </button>
                <p class = "payment_info"></p>
            </div>
        </div>

        <input type="checkbox" name="tracked">
        <p>Track the purchase to know more about it before it reaches you</p>



        <div class="navigation-buttons">
            <button name="cancel2">Cancel</button>
            <button type = "submit">Confirm Payment</button>
        </div>
        <div id="errorCheckout" style="display: none; color: red; font-size: small;"></div>
    </form>
</div>
@endsection
