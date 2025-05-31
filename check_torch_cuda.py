# Contents of check_torch_cuda.py:
import torch

print(f"PyTorch version: {torch.__version__}")
print(f"Is CUDA available to PyTorch? : {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"CUDA version PyTorch is built with: {torch.version.cuda}") # Should be 12.1
    print(f"Number of GPUs available: {torch.cuda.device_count()}")
    if torch.cuda.device_count() > 0:
        print(f"Current CUDA device: {torch.cuda.current_device()}")
        print(f"Device name: {torch.cuda.get_device_name(0)}")
        try:
            print("Attempting simple CUDA tensor operation...")
            a = torch.tensor([1.0, 2.0]).cuda() # Move tensor to GPU
            print(f"Tensor successfully created on CUDA: {a}")
            b = a + a
            print(f"Computation on CUDA successful: {b}")
            print("Simple PyTorch CUDA test PASSED!")
        except RuntimeError as e:
            print(f"!!! PyTorch CUDA runtime error during simple operation: {e}")
    else:
        print("PyTorch sees CUDA but no devices.")
else:
    print("!!! CUDA is NOT available to PyTorch. Check installation and drivers.")