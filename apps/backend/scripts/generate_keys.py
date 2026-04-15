"""Generate RS256 key pair for JWT signing.

Usage:
    python scripts/generate_keys.py

Creates private.pem and public.pem in the backend directory.
You can then set them in .env or configure as file paths.
"""

import os
import sys

try:
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
except ImportError:
    print("Error: 'cryptography' package not installed.")
    print("Install with: pip install cryptography")
    sys.exit(1)


def generate_keypair(output_dir: str = ".") -> None:
    """Generate an RSA 2048-bit key pair for JWT RS256 signing."""
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    # Save private key (PEM, no password)
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption(),
    )

    # Save public key
    public_key = private_key.public_key()
    public_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    private_path = os.path.join(output_dir, "private.pem")
    public_path = os.path.join(output_dir, "public.pem")

    with open(private_path, "wb") as f:
        f.write(private_pem)
    print(f"Private key saved to: {private_path}")

    with open(public_path, "wb") as f:
        f.write(public_pem)
    print(f"Public key saved to: {public_path}")

    print("\nTo use in .env, set:")
    print(f"  JWT_PRIVATE_KEY=@{os.path.abspath(private_path)}")
    print(f"  JWT_PUBLIC_KEY=@{os.path.abspath(public_path)}")
    print("\nOr copy the PEM contents directly into .env as inline strings.")
    print("WARNING: Keep private.pem secure. Never commit it to git.")


if __name__ == "__main__":
    output = sys.argv[1] if len(sys.argv) > 1 else "."
    generate_keypair(output)
