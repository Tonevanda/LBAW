<?php

namespace App\Http\Controllers;

use App\Models\Purchase;
use Illuminate\Http\Request;

class PurchaseController extends Controller
{

    /*public function index($user_id){
        $purchase = Purchase::findOrFail($user_id);
        dd($purchase);
        return view('purchase_history', [
            'products' => $purchase->products()->get()
        ]);

    }*/
    
   public function store($user_id){
        $data = request()->validate([
            'price' => 'required',
            'quantity' => 'required',
        ]);
        $data['user_id']=$user_id;
        $data['payment_type']="paypal";
        $data['destination']="Rua 1 2º andar 1234-567 Lisboa";
        $data['orderarrivedat']='2025-09-08 14:35:03+02';                                   //these values are temporary
        $data['stage_state']="payment";
        Purchase::create($data);
        return redirect()->route('shopping-cart', $data['user_id']);
    }
}
