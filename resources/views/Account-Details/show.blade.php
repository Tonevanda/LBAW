@extends('layouts.app') 

@section('content')

@php
$user = Auth::user();
$auth = $user->authenticated()->first();
$wallet = $auth->wallet()->first();
$currency = $wallet->currency()->first();
@endphp

<div class="account-page">
<h2> {{$user->name}} Account </h2>


<div class = "details_box">

    <h3><i class="fas fa-shopping-cart"></i>History - Store and Purchases</h3>
    <div class="ad_box">
    <div class="ad_wallet">  
    <h4> Wallet Balance: {{number_format($wallet->money, 2, ',', '.')}}{{$currency->currency_symbol}}</h4>
    <a class = "ad_button" href="{{ route('wallet',$user->id) }}">
        <i class="fas fa-plus"></i> Add funds to your Bibliophile Bliss Wallet</a>
    </div>
    <p> {{$auth->paymentMethod == NULL ? 'You have no payment methods associated with this account.' : ''}}
        <a class = "blue" href="#"> Add a payment method to this account.</a>
    </p>
    <p> If you've moved to a different country, you can update your Bibliophile Bliss Wallet currency and how you view the Books. 
        <a class = "blue" href="#"> Update Currency.</a>
    </p>
</div>
    <a class = "ad_button2" href="{{route('purchase_history',$user->id)}}"> View Purchase History</a>
</div>
<div class = "details_box">
    <h3><i class="fas fa-user"></i>Profile Information</h3>
    <div class="ad_box">
    <p><b> Name: </b>{{$user->name}} </p>
    <p><b> E-mail: </b>{{$user->email}} </p>
    <a class="edit" href="{{route('profile', $user->id)}}"> <i class="fas fa-edit"></i>Edit profile information</a>
</div>
    <form method="POST" action="{{ route('user.delete', ['user_id' => $user->id]) }}">
        {{ csrf_field() }}
        @method('DELETE')
        <button type="submit" class="cancel">
            Delete Account
        </button>
        <p class="small"> After deleting the account all of your reviews will remain in Bibliophile Bliss, avaliable for everyone, but with your name removed.</p>
    </form>
</div>
</div>
@endsection