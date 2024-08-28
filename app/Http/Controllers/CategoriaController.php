<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Categoria;

class CategoriaController extends Controller
{
    public function create()
    {
        return view('categorias.categorias_create');
    }

    public function store(Request $request)
    {

        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
        ]);

        Categoria::create($validation);

        return redirect()->route('categorias_index')->with('mensaje', 'Categoría creada exitosamente!');
    }

    public function index()
    {
        $categorias = Categoria::all();
        return view('categorias.categorias_index', compact('categorias'));
    }

    public function destroy($id)
    {
        $categoria = Categoria::find($id);
        $categoria->delete();
        return redirect()->route('categorias_index')->with('mensaje', 'Categoría eliminada exitosamente!');
    }

    public function edit($id)
    {
        $categoria = Categoria::find($id);
        return view('categorias.categorias_edit', compact('categoria'));
    }

    public function update(Request $request, $id)
    {
        $validation = $request->validate([
            'nombre' => 'required|max:255',
            'descripcion' => 'required|max:255',
        ]);
        $categoria = Categoria::find($id);
        $categoria->update($validation);
        return redirect()->route('categorias_index')->with('mensaje', 'Categoría actualizada exitosamente!');
    }
}

