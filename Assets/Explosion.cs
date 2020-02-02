using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Explosion : MonoBehaviour
{
    [SerializeField] Renderer _renderer = null;
    [SerializeField] Texture2D _noiseTexture = null;
    [SerializeField] Material _explosionMaterial = null;
    [SerializeField] Material _explosionSmokeMaterial = null;
    [SerializeField] Gradient _colorOverTime = null;
    [SerializeField] Gradient _smokeColorOverTime = null;
    [SerializeField] float _explosionLifetime = 0.3f;
    [SerializeField] float _smokeLifetime = 5f;
    [SerializeField] float _explosionRadius = 6.5f;

    float _elapsedTime = 0f;
    Vector3 _vortexAxis0 = default;
    Vector3 _vortexAxis1 = default;
    Vector3 _vortexAxis2 = default;

    MaterialPropertyBlock _cacheMaterialPropertyBlock;

    void Start()
    {
        Shader.SetGlobalTexture("_NoiseLUT", _noiseTexture);
        _cacheMaterialPropertyBlock = new MaterialPropertyBlock();
        StartNewExplosion();
    }

    void StartNewExplosion()
    {
        _elapsedTime = 0;
        _vortexAxis0 = Random.onUnitSphere;
        _vortexAxis1 = Random.onUnitSphere;
        _vortexAxis2 = Random.onUnitSphere;
        _renderer.sharedMaterial = _explosionMaterial;
        transform.localScale = Vector3.zero;
    }

    public static float EaseOut(float t)
    {
        t = Mathf.Clamp01(t);
        return t*(2 - t);
    }


    float CalculateExplosionRadius(float elapsedTime)
    {
        float t = Mathf.Clamp01(elapsedTime / _explosionLifetime);

        t *= 0.5f; // this is to make the explosion end with some velocity

        t = EaseOut(t);

        t /= EaseOut(0.5f);

        return _explosionRadius*t;
    }

    Color CalculateExplosionColor(float elapsedTime)
    {
        float t = Mathf.Clamp01(elapsedTime / _explosionLifetime);

        return _colorOverTime.Evaluate(t);
    }

    float CalculateExplosionColorMultplier(float elapsedTime)
    {
        float t = Mathf.Clamp01(elapsedTime / _explosionLifetime);

        t = EaseOut(t);

        t = Mathf.Pow(t, 0.6f);

        return Mathf.Lerp(3.5f, 1f, t);
    }

    void Update()
    {
        _elapsedTime += Time.deltaTime;

        if(_elapsedTime < _explosionLifetime)
        {
            float explosionRadius = CalculateExplosionRadius(_elapsedTime);
            Color explosionColor = CalculateExplosionColor(_elapsedTime);
            float colorMultiplier = CalculateExplosionColorMultplier(_elapsedTime);

            _cacheMaterialPropertyBlock.Clear();
            _cacheMaterialPropertyBlock.SetColor("_Color", colorMultiplier*explosionColor);

            transform.localScale = new Vector3(explosionRadius, explosionRadius, explosionRadius);
            _renderer.SetPropertyBlock(_cacheMaterialPropertyBlock);
        }
        else
        {
            _renderer.sharedMaterial = _explosionSmokeMaterial;

            float t = (_elapsedTime - _explosionLifetime) / _smokeLifetime;

            float explosionRadius = _explosionRadius;

            _cacheMaterialPropertyBlock.Clear();
            _cacheMaterialPropertyBlock.SetColor("_Color", _smokeColorOverTime.Evaluate(t));
            _cacheMaterialPropertyBlock.SetFloat("_ElapsedTime", Mathf.Pow(EaseOut(t), 0.5f));
            _cacheMaterialPropertyBlock.SetVector("_VortexAxis0", _vortexAxis0);
            _cacheMaterialPropertyBlock.SetVector("_VortexAxis1", _vortexAxis1);
            _cacheMaterialPropertyBlock.SetVector("_VortexAxis2", _vortexAxis2);

            transform.localScale = new Vector3(explosionRadius, explosionRadius, explosionRadius);
            _renderer.SetPropertyBlock(_cacheMaterialPropertyBlock);
        }

        if(_elapsedTime >= _explosionLifetime + _smokeLifetime)
        {
            StartNewExplosion();
        }
    }
}
