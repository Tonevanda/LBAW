<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{   
    //Show all products
    public function index(Request $request){
        $products = Product::filter($request->input())->paginate(12);
        return view('products.index', ['products' => $products]);
    }

    //Show a single product
    public function show($product_id){
        $product = Product::findOrFail($product_id);
        return view('products.show', [
            'product' => Product::findOrFail($product->id)
        ]);
    }

}
