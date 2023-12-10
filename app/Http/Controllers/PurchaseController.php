<?php

namespace App\Http\Controllers;


use App\Models\Purchase;
use Illuminate\Http\Request;

class PurchaseController extends Controller{
    public function store(Request $request, $user_id)
{
    $data = $request->validate([
        'price' => 'required',
        'quantity' => 'required',
        'destination' => 'required',
        'payment_type' => 'required',
        //'isTracked' => 'required'
    ]);
    // Add debugging statements
    $daysToAdd = 3; // Change this to the number of days you want to add
    $data['orderarrivedat'] = now()->addDays($daysToAdd)->toDateTimeString();
    $data['user_id'] = $user_id;
    $data['stage_state'] = "payment";

    Purchase::create($data);
    //dd($data);
    // Add another debugging statement

    }
}
