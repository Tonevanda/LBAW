<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Currency extends Model
{
    use HasFactory;

    protected $table = 'currency';

    protected $primaryKey = 'currency_type';

    public $timestamps = false;

    protected $fillable = [
        'currency_type',
        'currency_symbol'
    ];


    public function wallet()
    {
        return $this->hasMany(Wallet::class, 'currency_type');
    }
}
