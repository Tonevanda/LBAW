@extends('layouts.app') 

@section('content')

@php
    use App\Models\Payment;

    $user = Auth::user();
    if(!$user->isAdmin()){
        $auth = $user->authenticated()->first();
        $payments = Payment::filter("store money")->get();
    }
@endphp


<h2> Add funds to your wallet </h2>

<h4> Add funds to {{$user->name}}'s wallet</h4>


<p> Funds in your wallet can be used to purchase any book on Bibliophile Bliss.

    You will have the opportunity to review your request before it is processed. </p>



<div class = "money_fund_option">
    <h3> Add 5{{$wallet->currencySymbol}} </h3>
    <button name = "show_popup" data-money = {{"5" . $wallet->currencySymbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 10{{$wallet->currencySymbol}} </h3>
    <button name = "show_popup" data-money = {{"10" . $wallet->currencySymbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 25{{$wallet->currencySymbol}} </h3>
    <button name = "show_popup" data-money = {{"25" . $wallet->currencySymbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 50{{$wallet->currencySymbol}} </h3>
    <button name = "show_popup" data-money = {{"50" . $wallet->currencySymbol}}>
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 100{{$wallet->currencySymbol}} </h3>
    <button name = "show_popup" data-money = {{"100" . $wallet->currencySymbol}}>
        Add funds
    </button>
</div>

<div class = "user_wallet">
    <h2> Your Bibliophile Bliss Account </h2>
    <p> Current Wallet Balance </p>
    <h2> {{ number_format($wallet->money/100, 2, ',', '.') }}{{$wallet->currencySymbol}} </h2>
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