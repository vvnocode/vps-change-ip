import subprocess
from typing import Tuple, Optional

class IPQualityChecker:
    def __init__(self, check_script: str):
        self.check_script = check_script

    def check(self) -> Tuple[bool, Optional[str]]:
        """
        执行IP质量检查
        
        Returns:
            Tuple[bool, Optional[str]]: 
            - 是否成功
            - 错误信息（如果失败）
        """
        try:
            if not self.check_script:
                return False, "未配置检查脚本"

            # 运行脚本并捕获输出
            process = subprocess.Popen(
                ["bash", "-c", self.check_script],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # 等待脚本执行完成并获取输出
            stdout, stderr = process.communicate()
            
            return True, None
                
        except Exception as e:
            return False, str(e) 