@extends('layouts.app')

@php
    use App\Models\Payment;

    $payments = Payment::all();
    $user = Auth::user();
    if(!$user->isAdmin()){
        $auth = $user->authenticated()->first();
        $wallet = $auth->wallet();
    }
    $total = 0;
    $productCount = count($products);
@endphp

@section('content')
<div class="shopping-cart-page">
    <h2>Shopping Cart</h2>
    <div class="shopping-page">
    @foreach ($products as $product)
    @php
        $total = $total+($product->price-($product->discount*$product->price/100));
    @endphp
        <x-cart-product-card :product="$product" :user="$user"/>
    @endforeach
    <table>
        <tr>
            <td>Quantity</td>
            <td>{{ $productCount }}</td>
        </tr>
        <tr>
            <td>Price</td>
            <td>{{ number_format($total/100, 2, ',', '.');}}{{$user->isAdmin() ? '€' : $wallet->currencySymbol}}</td>
        </tr>
    </table>
    <button name="show_popup_checkout">
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

<div id="fullScreenPopup" class="popup-form" style="display: none;">
    <form class = "add_funds_form" method="" action="">
        {{ csrf_field() }}

        <input type = "text" name = "user_id" data-info = "{{$user->id}}" hidden>
        <!-- Your form content here -->
        <h3 class="title">Payment Information</h3>
        <!-- Separate fields for shipping address -->
        <h4>Billing information</h4>
            <div class="shipping-address">
                <div class="column">
                    <label for="name">Name</label>
                    <input type="text" name="name" placeholder="Enter name" data-info = "{{$auth->name == NULL ? '' : $auth->name}}">

                    <label for="address">Billing address</label>
                    <input type="text" name="address" placeholder="Enter Billing address" data-info = "{{$auth->address == NULL ? '' : $auth->address}}">

                    <label for="country">Country</label>
                    <select name="country" data-info = "{{$user->country}}">
                        <option value="{{$user->country}}">{{$user->country}}</option>
                        <option value="Other">Other</option>
                    
                    </select>
                </div>
                <div class="column">
                    <label for="city">City</label>
                    <input type="text" name="city" placeholder="Enter city" data-info = "{{$auth->city == NULL ? '' : $auth->city}}">
            
                    <label for="postal_code">Postal Code</label>
                    <input type="text" name="postal_code" placeholder="Enter Postal Code" data-info = "{{$auth->postal_code == NULL ? '' : $auth->postal_code}}">

                    <label for="phone">Phone Number</label>
                    <input type="text" name="phone" placeholder="Enter Phone Number" data-info = "{{$auth->phone_number == NULL ? '' : $auth->phone_number}}">
                </div>
            </div>

        <!-- Payment Method -->
        <h4>Payment Method</h4>
        <label for="payment_type">Choose a payment method:</label>
        <select name="payment_type" data-info = "{{$auth->payment_method == NULL ? $payments[0]->payment_type : $auth->payment_method}}">
            @foreach($payments as $payment)
                <option value="{{$payment->payment_type}}">{{$payment->payment_type}}</option>
            @endforeach
        </select>

        <input type="checkbox" name="remember">
        <p>Save my payment information to make checkout easier next time</p>

        <p>You will have the opportunity to review your purchase before finalizing it.</p>
        <!-- Add buttons for navigation -->
        <div class="navigation-buttons">
            <button name="cancel">Cancel</button>
            <button name="show_popup2">Continue</button>
        </div>
    </form>
</div>


{{--<div id="fullScreenPopup" class="popup-form" style="display: none;">
    <form class = "checkout" method="POST" action="{{ route('purchase.store', ['user_id' => $user->id]) }}">
        {{ csrf_field() }}
        <!-- Your form content here -->
        <input type="hidden" name="quantity" value="{{ $productCount }}">
        <input type="hidden" name="price" value="{{ $total }}">
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
        <p>Tracking<p>
        <label for="isTracked">Do you want to track your order?</label>
        <input type="checkbox" id="isTracked" name="isTracked" value="0">
        <span>Yes, I want my order to be tracked.</span>
        <!-- Add buttons for navigation -->
        <div class="navigation-buttons">
            <button name="cancel">Cancel</button>
            <button type="submit">Confirm Purchase</button>
        </div>
    </form>
</div>--}}
@endsection
