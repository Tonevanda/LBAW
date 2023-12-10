@extends('layouts.app') 

@section('content')

@php
$user = Auth::user();
$auth = $user->authenticated()->first();
$wallet = $auth->wallet();
@endphp


<h2> {{$user->name}} Account </h2>


<div class = "details_box">

    <i class="fas fa-shopping-cart"> History - Store and Purchases</i>

    <a href="#"> + Add funds to your Bibliophile Bliss Wallet</a>
    <p> Wallet Balance </p>
    <p> {{number_format($wallet->money, 2, ',', '.')}}{{$wallet->currencySymbol}}</p>
</div>
@endsection