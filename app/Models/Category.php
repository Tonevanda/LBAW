<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $table = 'category';

    public $timestamps = false;

    public $incrementing = false;

    protected $primaryKey = 'category_type';

    protected $fillable = [
        'category_type'
    ];
    



}