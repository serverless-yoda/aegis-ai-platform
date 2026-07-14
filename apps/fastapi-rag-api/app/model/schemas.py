from pydantic import BaseModel, Field

class AgentRequest(BaseModel):
    """
    Represents a request to the agent with a prompt.

    Attributes:
        prompt (str): The input prompt for the agent.
    """

    prompt: str = Field(..., description="The input prompt for the agent.") 