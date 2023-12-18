<?php

namespace App\Http\Controllers;


use App\Models\Purchase;
use Illuminate\Http\Request;
use Illuminate\Auth\Access\AuthorizationException;

class PurchaseController extends Controller
{

    
    public function store(Request $request, $user_id)
    {
        
        /*$data = $request->validate([
            'price' => 'required',
            'quantity' => 'required',
            'payment_type' => 'required',
            'destination' => 'required',
            'istracked' => 'required'
        ]);

        // Add additional fields or modify as needed
        $daysToAdd = 3; // Change this to the number of days you want to add
        $data['orderarrivedat'] = now()->addDays($daysToAdd)->toDateTimeString();
        $data['user_id'] = $user_id;
        $data['stage_state'] = "payment";


        // Create the Purchase record

        try {
            $this->authorize('create', Purchase::class);
        } catch (AuthorizationException $e) {
            return redirect()->route('all-products');
        }

        Purchase::create($data);*/
        return response()->json([], 200);



    }
}

