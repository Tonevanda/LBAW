@extends('layouts.app') 

@section('content')


<h2> Add funds to your wallet </h2>

<h4> Add funds to {{Auth::user()->name}}'s wallet</h4>


<p> Funds in your wallet can be used to purchase any book on Bibliophile Bliss.

    You will have the opportunity to review your request before it is processed. </p>



<div class = "money_fund_option">
    <h3> Add 5€ </h3>
    <a class="button" href="#">Add funds</a>
</div>

<div class = "money_fund_option">
    <h3> Add 10€ </h3>
    <a class="button" href="#">Add funds</a>
</div>

<div class = "money_fund_option">
    <h3> Add 25€ </h3>
    <a class="button" href="#">Add funds</a>
</div>

<div class = "money_fund_option">
    <h3> Add 50€ </h3>
    <a class="button" href="#">Add funds</a>
</div>

<div class = "money_fund_option">
    <h3> Add 100€ </h3>
    <a class="button" href="#">Add funds</a>
</div>

<div class = "user_wallet">
    <h2> Your Bibliophile Bliss Account </h2>
    <p> Current Wallet Balance </p>
    <h2> {{ number_format($wallet->money, 2, ',', '.') }}{{$wallet->currencySymbol}} </h2>
    <a class="button" href="{{ route('account_details',Auth::user()->id) }}">See Account Details</a>
</div>

@endsection