"""Browser journey against the loopback demo; requires Selenium Chrome driver."""

import os

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as conditions
from selenium.webdriver.support.ui import Select, WebDriverWait


def test_creator_sees_fleet_reports_and_stale_gps() -> None:
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    driver = webdriver.Chrome(options=options)
    try:
        driver.get(os.environ["FLEETOPS_DEMO_BASE_URL"])
        Select(driver.find_element(By.ID, "username")).select_by_value("demo_creator")
        driver.find_element(By.ID, "password").send_keys(
            os.environ["FLEETOPS_DEMO_PASSWORD"])
        driver.find_element(By.XPATH, "//button[normalize-space()='Sign in']").click()
        wait = WebDriverWait(driver, 15)
        wait.until(conditions.element_to_be_clickable((By.XPATH, "//button[normalize-space()='Reports']"))).click()
        wait.until(conditions.presence_of_element_located((By.XPATH, "//*[contains(text(),'Equipment by type')]")))
        assert "Operating cost report" in driver.page_source
        driver.find_element(By.XPATH, "//button[normalize-space()='GPS']").click()
        wait.until(conditions.presence_of_element_located((By.XPATH, "//*[contains(text(),'Last known truck positions')]")))
        assert "Observed" in driver.page_source
        driver.find_element(By.XPATH, "//button[normalize-space()='Ask Copilot']").click()
        wait.until(conditions.presence_of_element_located((By.XPATH, "//*[contains(text(),'FleetOps Copilot')]")))
        driver.find_element(By.XPATH, "//button[normalize-space()='New chat']").click()
        driver.find_element(By.ID, "copilot-question").send_keys("Assign truck DEMO-101")
        driver.find_element(By.XPATH, "//button[normalize-space()='Send']").click()
        wait.until(conditions.presence_of_element_located((By.XPATH, "//*[contains(text(),'cannot change them')]")))
        driver.find_element(By.XPATH, "//button[normalize-space()='Delete current chat']").click()
    finally:
        driver.quit()
