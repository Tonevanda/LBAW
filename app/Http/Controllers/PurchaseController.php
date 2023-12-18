<?php

namespace App\Http\Controllers;


use App\Models\Purchase;
use Illuminate\Http\Request;
use Illuminate\Auth\Access\AuthorizationException;

class PurchaseController extends Controller
{

    
    public function store(Request $request, $user_id)
    {
        
        $data = $request->validate([
            'price' => 'required',
            'quantity' => 'required',
            'payment_type' => 'required',
            'destination' => 'required',
            'istracked' => 'required'
        ]);

        

        $daysToAdd = 3; 
        $data['orderarrivedat'] = now()->addDays($daysToAdd)->toDateTimeString();
        $data['user_id'] = $user_id;
        $data['stage_state'] = "payment";


        try {
            $this->authorize('create', Purchase::class);
        } catch (AuthorizationException $e) {
            return redirect()->route('all-products');
        }

        Purchase::create($data);
        return response()->json([], 200);



    }
}

