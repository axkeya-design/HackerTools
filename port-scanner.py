import asyncio
import sys
import time

async def scan_port(ip, port, semaphore):
    async with semaphore:
        try:
            reader, writer = await asyncio.wait_for(
                    asyncio.open_connection(ip, port), timeout=1.0
            )

            print(f"port {port:<5} is open")
            
            writer.close()
            await writer.wait_closed()
            return port
        except (asyncio.TimeoutError, ConnectionRefusedError, OSError):
            return None

async def main():
    if len(sys.argv) < 2:
        print("Error")
        sys.exit(1)

    target_ip = sys.argv[1]

    start_port = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    end_port = int(sys.argv[3]) if len(sys.argv) > 3 else 1024

    print(f"Target IP:  {target_ip}")
    print(f"Scan depth: {start_port} - {end_port}")
    print("---------------------------------------")

    start_time = time.time()

    sem = asyncio.Semaphore(200)

    tasks = []
    for port in range(start_port, end_port + 1):
        tasks.append(scan_port(target_ip, port, sem))

    results = await asyncio.gather(*tasks)

    open_ports = [p for p in results if p is not None]

    end_time = time.time()

    print(f"Done in {end_time - start_time:.2f}s")
    print(f"Found {len(open_ports)} open ports")


if __name__ == "__main__":
    asyncio.run(main())
