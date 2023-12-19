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
            'price' => 'required',
            'quantity' => 'required',
            'payment_type' => 'required',
            'destination' => 'required',
            'istracked' => 'required'
        ]);
        $auth = Authenticated::findOrFail($user_id);
        $cart_products = $auth->shoppingCartSameProduct();
        $longest_days = 0;
        foreach ($cart_products as $cart_product) {
            $stock = 0;
            foreach ($cart_product as $product) {
                $stock = $stock+1;
                if($product->orderStatus > $longest_days){
                    $longest_days = $product->orderStatus;
                }
                try{
                    $this->authorize('hasStock', [$product, $stock]);
                }catch(AuthorizationException $e){
                    return response()->json($e->getMessage(), 301);
                }
            }
            
        }

        $date = now()->addDays($longest_days);
        $date->addHours(random_int(0, 48));
        $date->addMinutes(random_int(0, 59));
        $data['orderarrivedat'] = $date->toDateTimeString();
        $data['user_id'] = $user_id;


        try {
            $this->authorize('create', Purchase::class);
        } catch (AuthorizationException $e) {
            return response()->json($e->getMessage(), 301);
        }

        Purchase::create($data);
        return response()->json([], 200);



    }
}

