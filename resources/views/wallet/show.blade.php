@extends('layouts.app') 

@section('content')

<div class = "wallet">
    <h2> {{ $wallet->money }} </h2>
    <p> {{ $wallet->currency_type }} </p>
    <p> {{ $wallet->transaction_date }} </p>
</div>

@endsection