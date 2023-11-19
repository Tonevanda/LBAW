<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description', 'price'];

    protected $table = 'product';

    public $timestamps = false;

    protected $primaryKey = 'id';

    public function showAllBuyers()
    {
        return $this->belongsToMany(Authenticated::class, 'shopping_cart');
    }

    public function scopeFilter($query, array $filters)
    {
        $search_filter = '1 = ?';
        $name_filter = '1';
        if($filters['price'] ?? true){
            $filters['price'] = '250';
        }
        if($filters['category'] ?? false){
            $category_filter = 'category_type = ?';
        }
        else{
            $category_filter = '1 = ?';
            $filters['category'] = '1';
        }
        if($filters['search'] ?? false){       
                $search_array = array_filter(explode(' ',$filters['search']));
                while(!empty($search_array)){
                    $name_filter = implode('&', $search_array).':*';
                    $temp_query =  clone $query;
                    $temp_query->whereRaw('tsvectors @@ to_tsquery(\'english\', ?)', [$name_filter])
                          ->orderByRaw('ts_rank(tsvectors, to_tsquery(\'english\', ?)) DESC', [$name_filter]);

                    array_pop($search_array);
                    
                    if($temp_query->exists())break;
                }
                $search_filter = 'tsvectors @@ to_tsquery(\'english\', ?)';
        };
        $query->leftJoin('product_category', 'product_category.product_id', '=', 'product.id')
              ->whereRaw($category_filter, [$filters['category']])
              ->where('price', '<=', $filters['price'])
              ->whereRaw($search_filter, [$name_filter])
              ->orderByRaw('ts_rank(tsvectors, to_tsquery(\'english\', ?)) DESC', [$name_filter]);
    }

}
