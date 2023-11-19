<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{   
    //Show all products
    public function index(Request $request){
        //dd($request->input());
        $products = Product::filter($request->input())->paginate(10);
            //dd($products);
        //dd($products[0]);

        //dd($products[0]->name);
        return response()->json($products[0]);
        //return view('products.index', ['products' => $products]);
    }

    //Show a single product
    public function show(Product $product){
        return view('products.show', [
            'product' => Product::findOrFail($product->id)
        ]);
    }

}
