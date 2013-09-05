#pragma once

#include <wrl/client.h>
#include <d3d11_1.h>

enum ShaderId
{
   vsSimple,
   psSimple,
};


Microsoft::WRL::ComPtr<ID3D11VertexShader> nmeCreateVertexShader(
     Microsoft::WRL::ComPtr<ID3D11Device1> inDevice,
     Microsoft::WRL::ComPtr<ID3D11InputLayout> &outLayout,
     ShaderId inShader);

Microsoft::WRL::ComPtr<ID3D11PixelShader> nmeCreatePixelShader(Microsoft::WRL::ComPtr<ID3D11Device1> inDevice, ShaderId inShader);




