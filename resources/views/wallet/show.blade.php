@extends('layouts.app') 

@section('content')

@php
    use App\Models\Payment;

    $user = Auth::user();
    if(!$user->isAdmin()){
        $auth = $user->authenticated()->first();
        $payments = Payment::filter("store money")->get();
        $currency = $wallet->currency()->first();
    }
@endphp

<div class="wallet-page">

<div class="details_box">

<h3> Add funds to your wallet</h3>

<div class="ad_box">

<p> Funds in your wallet can be used to purchase any book on Bibliophile Bliss.

    You will have the opportunity to review your request before it is processed. </p>

<p> Choose the value you want to add. </p>
</div>
<div class = "money_fund_option">
    <h3> Add 5{{$currency->currency_symbol}} </h3>
    <button name = "show_popup" data-money = {{"5" . $currency->currency_symbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 10{{$currency->currency_symbol}} </h3>
    <button name = "show_popup" data-money = {{"10" . $currency->currency_symbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 25{{$currency->currency_symbol}} </h3>
    <button name = "show_popup" data-money = {{"25" . $currency->currency_symbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 50{{$currency->currency_symbol}} </h3>
    <button name = "show_popup" data-money = {{"50" . $currency->currency_symbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 100{{$currency->currency_symbol}} </h3>
    <button name = "show_popup" data-money = {{"100" . $currency->currency_symbol}}>
        Add funds
    </button>
</div>

<div class = "user_wallet">
    <h2> Your Bibliophile Bliss Account </h2>
    <p> Current Wallet Balance </p>
    <h2> {{ number_format($wallet->money/100, 2, ',', '.') }}{{$currency->currency_symbol}} </h2>
    <a class="button" href="{{ route('account_details',$user->id) }}">See Account Details</a>
</div>



<x-payment-popup-card :user="$user" :auth="$auth" :payments="$payments"/>




<div id="fullScreenPopup2" class="popup-form" style="display: none;">
    <form class = "add_funds_form" method="" action="">
        {{ csrf_field() }}
        <div class="shipping-address">
            <div class="column">
                <p>Being added to your Bibliophile Bliss Wallet</p>

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



        <div class="navigation-buttons">
            <button name="cancel2">Cancel</button>
            <button>Confirm Payment</button>
        </div>
    </form>
</div>
@endsection