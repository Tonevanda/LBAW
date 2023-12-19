@props(['user', 'auth', 'payments'])

@php
    $payment_value = $payments[0]->payment_type;

    if($auth->payment_method != null){
        if(!($payment_value != 'store money' && $auth->payment_method == 'store money'))
            $payment_value = $auth->payment_method;
    }
@endphp


<div id="fullScreenPopup" class="popup-form" style="display: none;">
    <form class = "add_funds_form" method="" action="">
        {{ csrf_field() }}

        <input type = "text" name = "user_id" data-info = "{{$user->id}}" hidden>
        <!-- Your form content here -->
        <h3 class="title">Payment Information</h3>
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
        <div class = "low_money" style="display: none;">
            <i class="fas fa-exclamation-triangle">Your Bibliophile Bliss Wallet balance is too low to cover this transaction!</i>
            <p></p>
            <input type="checkbox" name="all">
            <p></p>
        </div>
        <label for="payment_type">Choose a payment method:</label>
        <select name="payment_type" data-info = "{{$payment_value}}">
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