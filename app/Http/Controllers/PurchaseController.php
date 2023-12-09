<?php

namespace App\Http\Controllers;


use App\Models\Purchase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PurchaseController extends Controller
{

    /*public function index($user_id){
        $purchase = Purchase::findOrFail($user_id);
        dd($purchase);
        return view('purchase_history', [
            'products' => $purchase->products()->get()
        ]);

    }*/
    
   public function store(Request $request, $user_id){
    Log::info('Store method called. User ID: ' . $user_id);
    $data = $request->validate([
        'price' => 'required',
        'quantity' => 'required',
        'destination' => 'required',
        'payment_type' => 'required',
    ]);

        $data['user_id']=$user_id;
        $data['orderarrivedat']='2025-09-08 14:35:03+02';                                   //these values are temporary
        $data['stage_state']="payment";
    Log::info('Data to be inserted: ' . json_encode($data));
        Purchase::create($data);
        return redirect()->route('shopping-cart', $data['user_id']);
    }
}
