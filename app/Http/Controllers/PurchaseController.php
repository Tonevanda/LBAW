<?php

namespace App\Http\Controllers;


use App\Models\Purchase;
use Illuminate\Http\Request;

class PurchaseController extends Controller
{

    
    public function store(Request $request, $user_id)
    {
        $data = $request->validate([
            'price' => 'required',
            'quantity' => 'required',
            'city' => 'required',
            'state' => 'required',
            'street' => 'required',
            'postal_code' => 'required',
            'payment_type' => 'required',
            //'isTracked' => 'required'
        ]);

        // Concatenate the fields into the "destination" field
        $data['destination'] = $data['city'] . ', ' . $data['state'] . ', ' . $data['street'] . ', ' . $data['postal_code'];

        // Add additional fields or modify as needed
        $daysToAdd = 3; // Change this to the number of days you want to add
        $data['orderarrivedat'] = now()->addDays($daysToAdd)->toDateTimeString();
        $data['user_id'] = $user_id;
        $data['stage_state'] = "payment";

        // Create the Purchase record
        Purchase::create($data);

        // Redirect to the shopping cart or any other route as needed
        return redirect()->route('shopping-cart', $data['user_id']);
    }
}

