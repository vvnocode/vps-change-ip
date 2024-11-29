import subprocess
import os
from typing import Tuple, Optional
import pyautogui  # 用于截图

class IPQualityChecker:
    def __init__(self, check_script: str, screenshot_path: str):
        self.check_script = check_script
        self.screenshot_path = screenshot_path

    def check(self) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        执行IP质量检查
        
        Returns:
            Tuple[bool, Optional[str], Optional[str]]: 
            - 是否成功
            - 截图路径（如果成功）
            - 错误信息（如果失败）
        """
        try:
            if not self.check_script:
                return False, None, "未配置检查脚本"

            # 运行脚本并捕获输出
            process = subprocess.Popen(
                ["bash", "-c", self.check_script],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # 等待脚本执行完成并获取输出
            stdout, stderr = process.communicate()
            
            # 等待一段时间让页面加载完成
            import time
            time.sleep(2)  # 可以根据实际情况调整等待时间
            
            # 捕获屏幕截图
            try:
                screenshot = pyautogui.screenshot()
                screenshot.save(self.screenshot_path)
                return True, self.screenshot_path, None
            except Exception as e:
                return False, None, f"截图失败: {str(e)}"
                
        except Exception as e:
            return False, None, str(e)

    def cleanup(self):
        """清理临时文件"""
        try:
            if os.path.exists(self.screenshot_path):
                os.remove(self.screenshot_path)
        except Exception:
            pass 