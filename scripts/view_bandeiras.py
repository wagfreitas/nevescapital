#!/usr/bin/env python3
"""
Script para visualizar as imagens das bandeiras do arquivo bandeiras.json
Decodifica as imagens base64 e salva em arquivos para visualização
"""

import json
import base64
import os
from pathlib import Path

def main():
    # Caminho do arquivo JSON
    json_path = Path(__file__).parent.parent / 'assets' / 'bandeiras.json'
    
    # Diretório de saída
    output_dir = Path(__file__).parent.parent / 'assets' / 'bandeiras_images'
    output_dir.mkdir(exist_ok=True)
    
    # Lê o arquivo JSON
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"📁 Encontradas {len(data)} bandeiras no arquivo\n")
    print("=" * 60)
    
    # Processa cada bandeira
    for bandeira_name, bandeira_data in data.items():
        if 'image' not in bandeira_data:
            print(f"⚠️  {bandeira_name}: Sem imagem")
            continue
        
        image_data = bandeira_data['image']
        
        if not image_data.startswith('data:image'):
            print(f"⚠️  {bandeira_name}: Formato de imagem inválido")
            continue
        
        # Detecta o tipo de imagem
        if 'svg+xml' in image_data:
            ext = 'svg'
            mime_type = 'image/svg+xml'
        elif 'png' in image_data:
            ext = 'png'
            mime_type = 'image/png'
        elif 'jpg' in image_data or 'jpeg' in image_data:
            ext = 'jpg'
            mime_type = 'image/jpeg'
        else:
            ext = 'png'  # default
            mime_type = 'image/png'
        
        # Extrai o base64
        if ',' in image_data:
            base64_string = image_data.split(',')[1]
        else:
            # Tenta extrair de outra forma
            base64_string = image_data.split('base64,')[-1] if 'base64,' in image_data else image_data
        
        # Remove espaços
        base64_string = base64_string.replace(' ', '').replace('\n', '').replace('\r', '')
        
        try:
            # Decodifica
            image_bytes = base64.b64decode(base64_string)
            
            # Nome do arquivo (sanitizado)
            safe_name = bandeira_name.replace(' ', '_').replace('/', '_')
            output_file = output_dir / f"{safe_name}.{ext}"
            
            # Salva o arquivo
            with open(output_file, 'wb') as f:
                f.write(image_bytes)
            
            file_size = len(image_bytes)
            print(f"✅ {bandeira_name:30s} -> {output_file.name:40s} ({file_size:6d} bytes, {ext.upper()})")
            
        except Exception as e:
            print(f"❌ {bandeira_name}: Erro ao decodificar - {e}")
    
    print("=" * 60)
    print(f"\n📂 Imagens salvas em: {output_dir}")
    print(f"💡 Você pode visualizar as imagens abrindo a pasta acima\n")

if __name__ == '__main__':
    main()
