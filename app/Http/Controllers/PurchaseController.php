<?php

namespace App\Http\Controllers;


use App\Models\Purchase;
use Illuminate\Http\Request;
use Illuminate\Auth\Access\AuthorizationException;
use App\Models\Authenticated;

class PurchaseController extends Controller
{

    
    public function store(Request $request, $user_id)
    {
        
        $data = $request->validate([
            'payment_type' => 'required',
            'destination' => 'required',
            'istracked' => 'required'
        ]);



        $auth = Authenticated::findOrFail($user_id);
        try {
            $this->authorize('create', [Purchase::class, $user_id]);
        } catch (AuthorizationException $e) {
            return response()->json($e->getMessage(), 301);
        }


        $cart_products = $auth->shoppingCartSameProduct()->get();
        $total_quantity = 0;
        $total_price = 0;
        $temp_id = $cart_products[0]->id;
        $stock = 0;
        foreach ($cart_products as $product) {
            if($product->id != $temp_id){
                $stock = 0;
            }
            $stock = $stock+1;
            $total_quantity = $total_quantity + 1;
            $total_price = $total_price+$product->price;
            try{
                $this->authorize('hasStock', [$product, $stock]);
            }catch(AuthorizationException $e){
                return response()->json($e->getMessage(), 301);
            }
        }


        $wallet = $auth->wallet()->first();
        if($request->pay_all == "false" && $wallet->money < $total_price){
            if($wallet->money < $total_price){
                $wallet->money = 0;
            }
            else{
                $wallet->money = $wallet->money - $total_price;
            }
            $wallet_data = [
                'money' => $wallet->money,
                'currency_type' => $wallet->currency_type
            ];
            $wallet->update($wallet_data);
        }

        if($data['payment_type'] == 'store money'){
            $wallet->money = $wallet->money - $total_price;
            $wallet_data = [
                'money' => $wallet->money,
                'currency_type' => $wallet->currency_type
            ];
            $wallet->update($wallet_data);
        }


        $data['price'] = $total_price;
        $data['quantity'] = $total_quantity;
        $data['orderarrivedat'] = now()->addSeconds(5);
        $data['user_id'] = $user_id;

        Purchase::create($data);

        return response()->json($wallet->money, 201);

    }

    function update(Request $request, $purchase_id)
    {
        $data = $request->validate([
            'user_id' => 'required'
        ]);


        $purchase = Purchase::findOrFail($purchase_id);

        try{
            $this->authorize('update', [$purchase, $data['user_id']]);
        }
        catch(AuthorizationException $e){
            return response()->json(['message' => $e->getMessage(), 'purchase_id' => $purchase_id], 301);
        }


        $purchase->update(['refundedat' => now()->addMinutes(0, 2)->addSeconds(0, 30)]);
        
        return response()->json($purchase_id, 200);
    }


}

