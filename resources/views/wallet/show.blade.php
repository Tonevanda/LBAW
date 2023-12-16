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
    <h3> Add 5€ </h3>
    <button class = "show_popup">
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 10€ </h3>
    <button class = "show_popup">
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 25€ </h3>
    <button class = "show_popup">
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 50€ </h3>
    <button class = "show_popup">
        Add funds
    </button>
</div>

<div class = "money_fund_option">
    <h3> Add 100€ </h3>
    <button class = "show_popup">
        Add funds
    </button>
</div>

<div class = "user_wallet">
    <h2> Your Bibliophile Bliss Account </h2>
    <p> Current Wallet Balance </p>
    <h2> {{ number_format($wallet->money, 2, ',', '.') }}{{$wallet->currencySymbol}} </h2>
    <a class="button" href="{{ route('account_details',$user->id) }}">See Account Details</a>
</div>


<div id="fullScreenPopup" class="popup-form" style="display: none;">
    <form class = "add_funds_form" method="POST" action="{{ route('purchase.store', ['user_id' => $user->id]) }}">
        {{ csrf_field() }}
        <!-- Your form content here -->
        <p class="title">Checkout</p>
        <!-- Separate fields for shipping address -->
        <p>Purchase Destination<p>
            <div class="shipping-address">
                <div class="column">
                    <label for="city">City</label>
                    <input type="text" id="city" name="city" placeholder="Enter city">
            
                    <label for="street">Street</label>
                    <input type="text" id="street" name="street" placeholder="Enter street">
                </div>
                <div class="column">
                    <label for="state">State</label>
                    <input type="text" id="state" name="state" placeholder="Enter state">
            
                    <label for="postal_code">Postal Code</label>
                    <input type="text" id="postal_code" name="postal_code" placeholder="Enter Postal Code">
                </div>
            </div>

        <!-- Payment Method -->
        <p>Payment Method<p>
        <label for="payment_type">Choose a payment method:</label>
        <select id="payment_type" name="payment_type">
            @foreach($payments as $payment)
                @if($auth->paymentMethod == $payment->payment_type)
                    <option value="{{$payment->payment_type}}" selected>{{$payment->payment_type}}</option>
                @else
                    <option value="{{$payment->payment_type}}">{{$payment->payment_type}}</option>
                @endif
            @endforeach
        </select>

        <!-- Tracking -->
        <input type="checkbox" id="isTracked" name="isTracked" value="0">
        <span>Save my payment information to make checkout easier next time</span>
        <!-- Add buttons for navigation -->
        <div class="navigation-buttons">
            <button name="cancel">Cancel</button>
            <button type="submit">Confirm Purchase</button>
        </div>
    </form>
</div>

@endsection