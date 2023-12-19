@extends('layouts.app') 

@section('content')

@php
$user = Auth::user();
$auth = $user->authenticated()->first();
$wallet = $auth->wallet()->first();
$currency = $wallet->currency()->first();
@endphp


<h2> {{$user->name}} Account </h2>


<div class = "details_box">

    <i class="fas fa-shopping-cart"> History - Store and Purchases</i>

    <a class = "button" href="{{ route('wallet',$user->id) }}"> + Add funds to your Bibliophile Bliss Wallet</a>
    <p> Wallet Balance </p>
    <p> {{number_format($wallet->money/100, 2, ',', '.')}}{{$currency->currency_symbol}}</p>
    <p> {{$auth->paymentMethod == NULL ? 'You have no payment methods associated with this account.' : ''}}</p>
    <a class = "button" href="#"> Add a payment method to this account</a>
    <a class = "button" href="{{route('purchase_history',$user->id)}}"> View Purchase History</a>
    <p> If you've moved to a different country, you can update your Bibliophile Bliss Wallet currency and how you view the Books.</p>
    <a class = "button" href="#"> Update Currency</a>
</div>

<div class = "details_box">

    <i class="fas fa-user"> PROFILE INFORMATION</i>

    <p> Name: {{$user->name}} </p>
    <p> E-mail: {{$user->email}} </p>
    <a class = "button" href="{{route('profile', $user->id)}}">Change profile information</a>
    <form method="POST" action="{{ route('user.delete', ['user_id' => $user->id]) }}">
        {{ csrf_field() }}
        @method('DELETE')
        <button type="submit">
            Delete Account
        </button>
        <p> - After deleting the account all of your reviews will remain in Bibliophile Bliss, avaliable for everyone, but with your name removed.</p>
    </form>
    
</div>
@endsection