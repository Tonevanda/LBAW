<?php

namespace App\Http\Controllers;


use App\Models\Purchase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PurchaseController extends Controller{
    public function store(Request $request, $user_id)
{
    $data = $request->validate([
        'price' => 'required',
        'quantity' => 'required',
        'destination' => 'required',
        'payment_type' => 'required',
    ]);

    // Add debugging statements

    $data['user_id'] = $user_id;
    $data['orderarrivedat'] = '2025-09-08 14:35:03+02';
    $data['stage_state'] = "payment";

    dd(Purchase::create($data));
    //dd($data);
    // Add another debugging statement

    return redirect()->route('shopping-cart', $data['user_id']);
}
}