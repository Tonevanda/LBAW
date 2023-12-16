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
    <h2> {{ number_format($wallet->money, 2, ',', '.') }}{{$wallet->currencySymbol}} </h2>
    <a class="button" href="{{ route('account_details',$user->id) }}">See Account Details</a>
</div>


<div id="fullScreenPopup" class="popup-form" style="display: none;">
    <form class = "add_funds_form" method="POST" action="{{ route('purchase.store', ['user_id' => $user->id]) }}">
        {{ csrf_field() }}
        <!-- Your form content here -->
        <h3 class="title">Payment Information</h3>
        <!-- Separate fields for shipping address -->
        <h4>Billing information</h4>
            <div class="shipping-address">
                <div class="column">
                    <label for="name">Name</label>
                    <input type="text" name="name" placeholder="Enter name">

                    <label for="address">Billing address</label>
                    <input type="text" name="address" placeholder="Enter Billing address">

                    <label for="country">Country</label>
                    <select name="country">
                        <option value="" selected></option>
                        <option value="Portugal">Portugal</option>
                        <option value="USA">United States of America</option>
                    
                    </select>
                </div>
                <div class="column">
                    <label for="city">City</label>
                    <input type="text" name="city" placeholder="Enter city">
            
                    <label for="postal_code">Postal Code</label>
                    <input type="text" name="postal_code" placeholder="Enter Postal Code">

                    <label for="phone">Phone Number</label>
                    <input type="text" name="phone" placeholder="Enter Phone Number">
                </div>
            </div>

        <!-- Payment Method -->
        <h4>Payment Method</h4>
        <label for="payment_type">Choose a payment method:</label>
        <select name="payment_type">
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
        <p>Save my payment information to make checkout easier next time</p>

        <p>You will have the opportunity to review your purchase before finalizing it.</p>
        <!-- Add buttons for navigation -->
        <div class="navigation-buttons">
            <button name="cancel">Cancel</button>
            <button name="show_popup2">Continue</button>
        </div>
    </form>
</div>



<div id="fullScreenPopup2" class="popup-form" style="display: none;">
    <form class = "add_funds_form" method="POST" action="{{ route('purchase.store', ['user_id' => $user->id]) }}">
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
            <button type = "submit">Confirm Purchase</button>
        </div>
    </form>
</div>

@endsection